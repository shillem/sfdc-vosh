({
    asyncLoadDescriptor: function (cmp, campaignId) {
        const payload = {
            campaignId,
            recordId: cmp.get("v.recordId")
        };

        if (!payload.campaignId && !payload.recordId) {
            return;
        }

        const utils = cmp.find("utils");

        return utils
            .aura($A, {
                jsonify: true,
                method: cmp.get("c.auraGetRecord"),
                params: { payload }
            })
            .then(
                $A.getCallback(function ({ campaignName, descriptor }) {
                    cmp.set("v.campaignName", campaignName);
                    cmp.set("v.descriptor", descriptor);

                    cmp.set(
                        "v.record",
                        Object.values(descriptor.fieldMap).reduce((acc, { name, value }) => {
                            acc[name] = value;

                            return acc;
                        }, {})
                    );
                })
            )
            .catch(function (error) {
                cmp.set("v.error", utils.extractErrorMessages(error).join("\\n"));
            });
    }
});
