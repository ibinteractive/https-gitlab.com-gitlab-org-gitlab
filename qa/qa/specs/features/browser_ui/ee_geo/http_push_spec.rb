# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab HTTP push' do
      let(:file_name) { 'README.md' }

      # https://gitlab.com/gitlab-org/quality/nightly/issues/77
      context 'regular git commit', :quarantine do
        it 'is replicated to the secondary' do
          file_content = 'This is a Geo project!  Commit from primary.'

          Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
            # Visit the primary node and login
            Page::Main::Login.act { sign_in_using_credentials }

            # Create a new Project
            project = Resource::Project.fabricate! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project'
            end

            # Perform a git push over HTTP directly to the primary
            Resource::Repository::ProjectPush.fabricate! do |push|
              push.project = project
              push.file_name = file_name
              push.file_content = "# #{file_content}"
              push.commit_message = 'Add README.md'
            end
            project.visit!

            # Validate git push worked and file exists with content
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication

              expect(page).to have_content(file_name)
              expect(page).to have_content(file_content)
            end

            Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
              # Visit the secondary node and login
              Page::Main::OAuth.act { authorize! if needs_authorization? }

              EE::Page::Main::Banner.perform do |banner|
                expect(banner).to have_secondary_read_only_banner
              end

              Page::Main::Menu.perform { |menu| menu.go_to_projects }

              Page::Dashboard::Projects.perform do |dashboard|
                dashboard.wait_for_project_replication(project.name)
                dashboard.go_to_project(project.name)
              end

              # Validate the content has been sync'd from the primary
              Page::Project::Show.perform do |show|
                show.wait_for_repository_replication_with(file_name)

                expect(page).to have_content(file_name)
                expect(page).to have_content(file_content)
              end
            end
          end
        end
      end

      context 'git-lfs commit' do
        it 'is replicated to the secondary' do
          file_content = 'This is a Geo project!'
          lfs_file_content = 'The rendered file could not be displayed because it is stored in LFS.'

          Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
            # Visit the primary node and login
            Page::Main::Login.act { sign_in_using_credentials }

            # Create a new Project
            project = Resource::Project.fabricate! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project'
            end

            # Perform a git push over HTTP directly to the primary
            push = Resource::Repository::ProjectPush.fabricate! do |push|
              push.use_lfs = true
              push.project = project
              push.file_name = file_name
              push.file_content = "# #{file_content}"
              push.commit_message = 'Add README.md'
            end
            project.visit!

            expect(push.output).to match(/Locking support detected on remote/)
            expect(push.output).to match(%r{Uploading LFS objects: 100% \(1/1\)})

            # Validate git push worked and file exists with content
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication

              expect(page).to have_content(file_name)
              expect(page).to have_content(lfs_file_content)
            end

            Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
              # Visit the secondary node and login
              Page::Main::OAuth.act { authorize! if needs_authorization? }

              EE::Page::Main::Banner.perform do |banner|
                expect(banner).to have_secondary_read_only_banner
              end

              Page::Main::Menu.perform { |menu| menu.go_to_projects }

              Page::Dashboard::Projects.perform do |dashboard|
                dashboard.wait_for_project_replication(project.name)
                dashboard.go_to_project(project.name)
              end

              # Validate the content has been sync'd from the primary
              Page::Project::Show.perform do |show|
                show.wait_for_repository_replication_with(file_name)

                expect(page).to have_content(file_name)
                expect(page).to have_content(lfs_file_content)
              end
            end
          end
        end
      end
    end
  end
end
