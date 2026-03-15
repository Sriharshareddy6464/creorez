const fs = require("fs");
const { spawn } = require("child_process");

exports.handler = async (event) => {
    try {
        // Set all env vars first
        process.env.HOME = "/tmp";
        process.env.TECTONIC_CACHE_DIR = "/tmp/tectonic-cache";
        process.env.XDG_CACHE_HOME = "/tmp/cache";
        process.env.XDG_DATA_HOME = "/tmp/data";
        process.env.XDG_CONFIG_HOME = "/tmp/config";
        process.env.TMPDIR = "/tmp";

        // Create all required dirs
        try { fs.mkdirSync("/tmp/tectonic-cache", { recursive: true }); } catch { }
        try { fs.mkdirSync("/tmp/cache", { recursive: true }); } catch { }
        try { fs.mkdirSync("/tmp/data", { recursive: true }); } catch { }
        try { fs.mkdirSync("/tmp/config", { recursive: true }); } catch { }

        // Debug logs
        console.log("HOME:", process.env.HOME);
        console.log("TECTONIC_CACHE_DIR:", process.env.TECTONIC_CACHE_DIR);
        console.log("XDG_CACHE_HOME:", process.env.XDG_CACHE_HOME);

        // Check /tmp is writable
        try {
            fs.writeFileSync("/tmp/test.txt", "test");
            console.log("/tmp is writable ✅");
            fs.unlinkSync("/tmp/test.txt");
        } catch (e) {
            console.log("/tmp NOT writable ❌", e.message);
        }

        // List /tmp contents
        console.log("/tmp contents:", fs.readdirSync("/tmp"));

        // Parse body
        const body = typeof event.body === "string"
            ? JSON.parse(event.body)
            : event.body;

        const { code } = body;

        if (!code) {
            return {
                statusCode: 400,
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ error: "No LaTeX content provided" })
            };
        }

        const fileName = `resume-${Date.now()}`;
        const texPath = `/tmp/${fileName}.tex`;
        const pdfPath = `/tmp/${fileName}.pdf`;

        console.log("texPath:", texPath);
        console.log("pdfPath:", pdfPath);

        // Write LaTeX file
        try {
            fs.writeFileSync(texPath, code);
            console.log("✅ .tex file written successfully");
        } catch (err) {
            console.error("❌ Failed to write .tex:", err);
            return {
                statusCode: 500,
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ error: "Write failure" })
            };
        }

        // Run Tectonic
        await new Promise((resolve, reject) => {
            const cmd = spawn("/usr/local/bin/tectonic", [
                "--cache-dir", "/tmp/tectonic-cache",
                "--outdir", "/tmp",
                "--print",
                texPath
            ], {
                env: {
                    ...process.env,
                    HOME: "/tmp",
                    TECTONIC_CACHE_DIR: "/tmp/tectonic-cache",
                    XDG_CACHE_HOME: "/tmp/cache",
                    XDG_DATA_HOME: "/tmp/data",
                    XDG_CONFIG_HOME: "/tmp/config",
                    TMPDIR: "/tmp"
                }
            });

            cmd.stdout.on("data", data => console.log("TECTONIC STDOUT:", data.toString()));
            cmd.stderr.on("data", data => console.error("TECTONIC STDERR:", data.toString()));
            cmd.on("error", err => {
                console.error("❌ Spawn failed:", err);
                reject(err);
            });
            cmd.on("close", exit => {
                console.log("Tectonic exit code:", exit);
                if (exit === 0) resolve();
                else reject(new Error("Tectonic failed with exit code " + exit));
            });
        });

        // Read PDF
        let pdfBuffer;
        try {
            pdfBuffer = fs.readFileSync(pdfPath);
            console.log("✅ PDF read successfully, size:", pdfBuffer.length);
        } catch (err) {
            console.error("❌ Failed to read PDF:", err);
            return {
                statusCode: 500,
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ error: "PDF read error" })
            };
        }

        const base64PDF = pdfBuffer.toString("base64");

        // Cleanup
        try { fs.unlinkSync(texPath); } catch { }
        try { fs.unlinkSync(pdfPath); } catch { }

        return {
            statusCode: 200,
            headers: {
                "Content-Type": "application/pdf",
                "Content-Disposition": "attachment; filename=resume.pdf"
            },
            body: base64PDF,
            isBase64Encoded: true
        };

    } catch (err) {
        console.error("❌ SERVER ERROR:", err);
        return {
            statusCode: 500,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ error: "Internal server error" })
        };
    }
};