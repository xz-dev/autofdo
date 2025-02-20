TESTS = \
    pts/workstation \
    pts/stress-ng

Containerfile: template/Containerfile Makefile
	@echo 'Gen Containerfile...'
	@awk '/{{INSTALL_COMMANDS}}/ {exit} {print}' template/Containerfile > Containerfile
	@for TEST in $(TESTS); do \
	    echo "RUN phoronix-test-suite install-dependencies $$TEST && pacman --noconfirm -Scc" >> Containerfile; \
	    echo "RUN phoronix-test-suite install $$TEST" >> Containerfile; \
	done
	@awk 'f{print} /{{INSTALL_COMMANDS}}/ {f=1}' template/Containerfile >> Containerfile
