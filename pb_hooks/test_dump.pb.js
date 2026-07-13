routerAdd("POST", "/api/test-dump", (c) => {
    try {
        const info = $apis.requestInfo(c);
        console.log("=== REQUEST INFO ===");
        console.log("query:", JSON.stringify(info.query));
        console.log("data:", JSON.stringify(info.data));
        console.log("body:", JSON.stringify(info.body));
        
        let qEmail = c.queryParam("email");
        let fEmail = c.formValue("email");
        console.log("qEmail:", qEmail, "fEmail:", fEmail);
        
        return c.json(200, { success: true });
    } catch (e) {
        return c.json(500, { error: e.toString() });
    }
});
