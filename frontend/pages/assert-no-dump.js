// scripts/assert-no-dump.js - Validador HTML parcial-aware
const fs = require("fs");
const path = require("path");

// Excluir copias/backups y PARCIALES (components/sections)
const EXCLUDES = [
  /copia/i, /backup/i, /old/i, /-copy/i, /\.bak$/i,
  /frontend[\/\\](components|sections)[\/\\]/i
];

function listHtml(dir) {
  let out = [];
  for (const n of fs.readdirSync(dir)) {
    const p = path.join(dir, n);
    const st = fs.statSync(p);
    if (st.isDirectory()) out = out.concat(listHtml(p));
    else if (n.toLowerCase().endsWith(".html")) out.push(p);
  }
  return out.filter(f => !EXCLUDES.some(re => re.test(f)));
}

function check(file) {
  const html = fs.readFileSync(file, "utf8");
  
  // Si no hay <body>, consideramos que es parcial/plantilla => OK
  if (!/<body[^>]*>/i.test(html)) {
    return { file, ok: true, tail: "(partial or no <body>)", type: "partial" };
  }
  
  const i = html.lastIndexOf("</body>");
  if (i < 0) return { file, ok: false, tail: "(sin </body>)", type: "missing-body" };
  
  const tail = (html.slice(i + 7) || "").trim();
  if (!tail) return { file, ok: true, tail: "", type: "valid" };
  
  // Detectar contenido problemático específico
  const bad = /<footer|@keyframes|background\s*:|class="|<script|<style|<\/html>\s*<footer/i.test(tail);
  
  return { 
    file, 
    ok: !bad, 
    tail: tail.slice(0, 160).replace(/\s+/g, ' '),
    type: bad ? "problematic" : "minor"
  };
}

(function main() {
  const files = listHtml(process.cwd());
  const bad = [];
  let partials = 0;
  
  console.log(`🔍 Validando ${files.length} archivos HTML (excluyendo components/sections)...\n`);

  for (const f of files) {
    const r = check(f);
    if (r.type === "partial") {
      partials++;
    } else if (!r.ok) {
      bad.push(r);
    }
  }

  if (bad.length) {
    console.log("❌ HTML con contenido después de </body>:\n");
    bad.forEach((r, i) => {
      console.log(`${i + 1}. ${path.relative(process.cwd(), r.file)}`);
      console.log(`   └── ${r.tail}\n`);
    });
    console.log(`💡 Para corregir: node scripts/auto-fix-footer.js --apply\n`);
    process.exit(1);
  }

  console.log("✅ Sin dumps tras </body> en archivos activos.");
  if (partials > 0) {
    console.log(`📄 ${partials} parciales ignorados correctamente`);
  }
})();
  
  // Detectar contenido problemático
  const hasProblematicContent = /<footer|@keyframes|background\s*:|class="|<style|<script|<div|<p|<span/i.test(tail);
  
  return { 
    file, 
    ok: !hasProblematicContent, 
    tail: trimmedTail.slice(0, 160).replace(/\s+/g, ' ') 
  };
}

(function main() {
  const files = listHtml(process.cwd());
  const bad = [];
  
  console.log(`� Validando ${files.length} archivos HTML (excluyendo copias/backups)...\n`);

  for (const f of files) {
    const r = checkFile(f);
    if (!r.ok) bad.push(r);
  }

  if (bad.length) {
    console.log("❌ Archivos HTML con contenido problemático después de </body>:\n");
    bad.forEach((r, i) => {
      console.log(`${i + 1}. ${path.relative(process.cwd(), r.file)}`);
      console.log(`   └── Contenido: ${JSON.stringify(r.tail)}\n`);
    });
    console.log(`💡 Para corregir automáticamente: node scripts/auto-fix-footer.js --apply\n`);
    process.exit(1);
  }

  console.log("✅ Todos los archivos HTML activos están correctos (sin dumps tras </body>)");
})();
