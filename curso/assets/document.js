document.addEventListener('keydown', function(e) {
    if (e.key === 'F2') {
        document.getElementById('search-input')?.focus();
        e.preventDefault();
    }
    if (e.key === 'F9') {
        document.getElementById('checkout-btn')?.click();
        e.preventDefault();
    }
});
