#!/bin/bash

CUSTOM_VIB_FILE=stress.json
CUSTOM_VIB_NAME=nested-vsan-esa-mock-hw
CUSTOM_VIB_OFFLINE_BUNDLE_NAME=nested-vsan-esa-mock-hw-offline-bundle.zip
CUSTOM_VIB_VENDOR="williamlam.com"
CUSTOM_VIB_VENDOR_URL="https://williamlam.com"
CUSTOM_VIB_VSPHERE_UI_LABEL="Nested vSAN ESA Mock HW"
CUSTOM_VIB_SUMMARY="Nested vSAN ESA Mock HW VIB"
CUSTOM_VIB_DESCRIPTION="Nested vSAN ESA Mock HW VIB"
CUSTOM_VIB_ESXI_COMPAT=8 #compat with both ESXi 7.x and 8.x

### DO NOT EDIT BEYOND HERE ###

CUSTOM_VIB_TEMP_DIR=/tmp/vib-temp-$$
CUSTOM_VIB_VERSION="1.0.0-1.0"
CUSTOM_VIB_BUILD_DATE=$(date '+%Y-%m-%dT%H:%I:%S')

COLOR='\033[0;32m'
NOCOLOR='\033[0m'

echo -e "${COLOR}Creating Nested vSAN ESA Mock HW VIB${NOCOLOR} ..."

CUSTOM_VIB_FILE_NAME=${CUSTOM_VIB_NAME}.vib

# Setting up VIB spec confs
VIB_DESC_FILE=${CUSTOM_VIB_TEMP_DIR}/descriptor.xml
VIB_PAYLOAD_DIR=${CUSTOM_VIB_TEMP_DIR}/payloads/payload1

# Create VIB temp & spec payload directory
mkdir -p ${CUSTOM_VIB_TEMP_DIR}
mkdir -p ${VIB_PAYLOAD_DIR}

# Create ESXi folder structure for file(s) placement
CUSTOM_VIB_BIN_DIR=${VIB_PAYLOAD_DIR}/usr/lib/vmware/vsan/perfsvc
mkdir -p ${CUSTOM_VIB_BIN_DIR}

# Copy file(s) to destination folder
cp ${CUSTOM_VIB_FILE} ${CUSTOM_VIB_BIN_DIR}

# Create tgz with payload
tar czf ${CUSTOM_VIB_TEMP_DIR}/payload1 -C ${VIB_PAYLOAD_DIR} usr/lib/vmware/vsan/perfsvc

# Calculate payload size/hash
PAYLOAD_FILES=$(tar tf ${CUSTOM_VIB_TEMP_DIR}/payload1 | grep -v -E '/$' | sed -e 's/^/    <file>/' -e 's/$/<\/file>/')
PAYLOAD_SIZE=$(stat -c %s ${CUSTOM_VIB_TEMP_DIR}/payload1)
PAYLOAD_SHA256=$(sha256sum ${CUSTOM_VIB_TEMP_DIR}/payload1 | awk '{print $1}')
PAYLOAD_SHA256_ZCAT=$(zcat ${CUSTOM_VIB_TEMP_DIR}/payload1 | sha256sum | awk '{print $1}')
PAYLOAD_SHA1_ZCAT=$(zcat ${CUSTOM_VIB_TEMP_DIR}/payload1 | sha1sum | awk '{print $1}')

# Create descriptor.xml
cat > ${VIB_DESC_FILE} << __VIB_DESC__
<vib>
  <type>bootbank</type>
  <name>${CUSTOM_VIB_NAME}</name>
  <version>${CUSTOM_VIB_VERSION}</version>
  <vendor>${CUSTOM_VIB_VENDOR}</vendor>
  <summary>${CUSTOM_VIB_SUMMARY}</summary>
  <description>${CUSTOM_VIB_DESCRIPTION}</description>
  <release-date>${CUSTOM_VIB_BUILD_DATE}</release-date>
  <urls>
    <url key="website">${CUSTOM_VIB_VENDOR_URL}</url>
  </urls>
  <relationships>
    <depends>
    </depends>
    <conflicts/>
    <replaces/>
    <provides/>
    <compatibleWith/>
  </relationships>
  <software-tags>
  </software-tags>
  <system-requires>
    <maintenance-mode>false</maintenance-mode>
    <softwarePlatform version="${CUSTOM_VIB_ESXI_COMPAT}.*" locale="" productLineID="embeddedEsx" />
  </system-requires>
  <file-list>
${PAYLOAD_FILES}
  </file-list>
  <acceptance-level>community</acceptance-level>
  <live-install-allowed>true</live-install-allowed>
  <live-remove-allowed>true</live-remove-allowed>
  <cimom-restart>false</cimom-restart>
  <stateless-ready>true</stateless-ready>
  <overlay>false</overlay>
  <payloads>
    <payload name="payload1" type="tgz" size="${PAYLOAD_SIZE}">
        <checksum checksum-type="sha-256">${PAYLOAD_SHA256}</checksum>
        <checksum checksum-type="sha-256" verify-process="gunzip">${PAYLOAD_SHA256_ZCAT}</checksum>
        <checksum checksum-type="sha-1" verify-process="gunzip">${PAYLOAD_SHA1_ZCAT}</checksum>
    </payload>
  </payloads>
</vib>
__VIB_DESC__

# Create VIB using ar utility
touch ${CUSTOM_VIB_TEMP_DIR}/sig.pkcs7
ar r ${CUSTOM_VIB_FILE_NAME} ${VIB_DESC_FILE} ${CUSTOM_VIB_TEMP_DIR}/sig.pkcs7 ${CUSTOM_VIB_TEMP_DIR}/payload1

# Create offline bundle
PYTHONPATH=/opt/vmware/vibtools-6.0.0-847598/bin python -c "import vibauthorImpl; vibauthorImpl.CreateOfflineBundle(\"${CUSTOM_VIB_FILE_NAME}\", \"${CUSTOM_VIB_OFFLINE_BUNDLE_NAME}\", True)"

# re-author offline bundle to be component compliant vs bulletin for ESXi 7.x and later
echo -e "${COLOR}Creating compliant offline bundle for Nested vSAN ESA Mock HW VIB ...${NOCOLOR}"
CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY=${CUSTOM_VIB_OFFLINE_BUNDLE_NAME%.*}
unzip ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME} -d ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}
rm -f ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME}
chmod 644 -R ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}
sed -i 's/Unknown/WIL/g' ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/index.xml
sed -i "s/5.\*/${CUSTOM_VIB_ESXI_COMPAT}.\*/g" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/vendor-index.xml
unzip ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata.zip -d ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata
rm -f ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata.zip
sed -i "s/5.\*/${CUSTOM_VIB_ESXI_COMPAT}.\*/g" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/vendor-index.xml
sed -i "/<releaseDate>/i\    <componentNameSpec name=\"${CUSTOM_VIB_NAME}\" uiString=\"${CUSTOM_VIB_VSPHERE_UI_LABEL}\"\/>" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/vmware.xml
sed -i "/<releaseDate>/i\    <componentVersionSpec uiString=\"${CUSTOM_VIB_VERSION}\" version=\"${CUSTOM_VIB_VERSION}\"\/>" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/vmware.xml
sed -i "s/version=\"5./version=\"${CUSTOM_VIB_ESXI_COMPAT}./g" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/vmware.xml
sed -i "s|<kbUrl>.*|<kbUrl>${CUSTOM_VIB_VENDOR_URL}</kbUrl>|g" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/vmware.xml
sed -i "s|<releaseDate>|<componentNameSpec name=\"${CUSTOM_VIB_NAME}\" uiString=\"${CUSTOM_VIB_VSPHERE_UI_LABEL}\"/>&|" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/bulletins/nested-vsan-esa-mock-hw.xml
sed -i "s|<releaseDate>|<componentVersionSpec uiString=\"${CUSTOM_VIB_VERSION}\" version=\"${CUSTOM_VIB_VERSION}\"/>&|" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/bulletins/nested-vsan-esa-mock-hw.xml
sed -i "s/5.\*/${CUSTOM_VIB_ESXI_COMPAT}.\*/g" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/bulletins/nested-vsan-esa-mock-hw.xml
sed -i "s|<kbUrl>unknown</kbUrl>|<kbUrl>${CUSTOM_VIB_VENDOR_URL}</kbUrl>|g" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/bulletins/nested-vsan-esa-mock-hw.xml
sed -i "s|</system-requires>|<softwarePlatform version=\"${CUSTOM_VIB_ESXI_COMPAT}.*\" locale=\"\" productLineID=\"embeddedEsx\"/>&|" ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata/vibs/nested-vsan-esa-mock-hw-*.xml
cd ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}/metadata
zip -r ../metadata.zip bulletins/ vendor-index.xml vibs/ vmware.xml
cd ..
rm -rf metadata
zip -r ../${CUSTOM_VIB_OFFLINE_BUNDLE_NAME} index.xml metadata.zip vendor-index.xml vib20/
cd ..
rm -rf ${CUSTOM_VIB_OFFLINE_BUNDLE_NAME_EXTRACT_DIRECTORY}
