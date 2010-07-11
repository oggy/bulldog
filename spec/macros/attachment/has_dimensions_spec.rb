require 'spec_helper'

module HasDimensionsSpec
  def it_should_behave_like_an_attachment_with_dimensions(params)
    # For some reason, params gets clobbered by subsequent invocations
    # if this is a shared example group.
    def it_should_behave_like_whether_or_not_the_width_and_height_are_stored(params)
      describe 'for a new record with an attachment' do
        before do
          @thing = Thing.new(:attachment => uploaded_file(params[:file_40x30]))
        end

        describe "#width" do
          it "should return the width of the given style" do
            @thing.attachment.width(:original).should == 40
            @thing.attachment.width(:double).should == 80
          end

          it "should take into account the filledness of the style" do
            @thing.attachment.width(:filled).should == 60
            @thing.attachment.width(:unfilled).should == 120
          end

          it "should use the default style if no style is given" do
            @thing.attachment.width.should == 80
          end
        end

        describe "#height" do
          it "should return the height of the given style" do
            @thing.attachment.height(:original).should == 30
            @thing.attachment.height(:double).should == 60
          end

          it "should take into account the filledness of the style" do
            @thing.attachment.height(:filled).should == 60
            @thing.attachment.height(:unfilled).should == 90
          end

          it "should use the default style if no style is given" do
            @thing.attachment.height.should == 60
          end
        end

        describe "#dimensions" do
          it "should return the width and height of the given style" do
            @thing.attachment.dimensions(:original).should == [40, 30]
            @thing.attachment.dimensions(:double).should == [80, 60]
          end

          it "should take into account the filledness of the style" do
            @thing.attachment.dimensions(:filled).should == [60, 60]
            @thing.attachment.dimensions(:unfilled).should == [120, 90]
          end

          it "should use the default style if no style is given" do
            @thing.attachment.dimensions.should == [80, 60]
          end
        end

        describe "#aspect_ratio" do
          it "should return the aspect ratio of the given style" do
            @thing.attachment.aspect_ratio(:original).should be_close(4.0/3, 1e-5)
            @thing.attachment.aspect_ratio(:double).should be_close(4.0/3, 1e-5)
          end

          it "should take into account the filledness of the style" do
            @thing.attachment.aspect_ratio(:filled).should be_close(1, 1e-5)
            @thing.attachment.aspect_ratio(:unfilled).should be_close(4.0/3, 1e-5)
          end

          it "should use the default style if no style is given" do
            @thing.attachment.aspect_ratio.should be_close(4.0/3, 1e-5)
          end
        end

        describe "when the attachment is updated and the record reloaded" do
          before do
            @thing.update_attributes(:attachment => uploaded_file(params[:file_20x10]))
            @thing = Thing.find(@thing.id)
          end

          describe "#width" do
            it "should return the stored width for the original style" do
              @thing.attachment.width(:original).should == 20
            end
          end

          describe "#height" do
            it "should return the stored height for the original style" do
              @thing.attachment.height(:original).should == 10
            end
          end

          describe "#dimensions" do
            it "should return the stored width and height for the original style" do
              @thing.attachment.dimensions(:original) == [20, 10]
            end
          end

          describe "#aspect_ratio" do
            it "should use the stored width and height for the original" do
              @thing.attachment.aspect_ratio(:original).should be_close(2, 1e-5)
            end
          end
        end
      end
    end

    describe "when the width and height are stored" do
      use_model_class(:Thing,
                      :attachment_file_name => :string,
                      :attachment_width => :integer,
                      :attachment_height => :integer)

      before do
        Thing.has_attachment :attachment do
          type params[:type]
          style :double, :size => '80x60'
          style :filled, :size => '60x60', :filled => true
          style :unfilled, :size => '120x120'
          default_style :double
        end
      end

      it_should_behave_like_whether_or_not_the_width_and_height_are_stored(params)

      describe "when a record is instantiated" do
        before do
          @thing = Thing.new
        end

        describe "when the attachment is assigned a file" do
          before do
            @thing.attachment = uploaded_file(params[:file_40x30])
          end

          it "should set the stored attributes" do
            @thing.attachment_width.should == 40
            @thing.attachment_height.should == 30
          end

          describe "when the record is saved" do
            before do
              @thing.save!
            end

            describe "when the record is reinstantiated" do
              it "should not make any system calls to find the dimensions"
            end

            describe "when the stored values are hacked, and the record is reinstantiated" do
              before do
                Thing.update_all(
                  {:attachment_width => 100, :attachment_height => 10},
                  {:id => @thing.id}
                )
                @thing = Thing.find(@thing.id)
              end

              describe "#width" do
                it "should use the stored width for the original" do
                  @thing.attachment.width(:original).should == 100
                end

                it "should calculate the width of other styles from that of the original" do
                  @thing.attachment.width(:double).should == 80
                end
              end

              describe "#height" do
                it "should use the stored height for the original" do
                  @thing.attachment.height(:original).should == 10
                end

                it "should calculate the height of other styles from that of the original" do
                  @thing.attachment.height(:double).should == 8
                end
              end

              describe "#dimensions" do
                it "should use the stored width and height for the original" do
                  @thing.attachment.dimensions(:original).should == [100, 10]
                end

                it "should calculate the width and height of other styles from those of the original" do
                  @thing.attachment.dimensions(:double).should == [80, 8]
                end
              end

              describe "#aspect_ratio" do
                it "should use the stored width and height for the original" do
                  @thing.attachment.aspect_ratio(:original).should be_close(10, 1e-5)
                end

                it "should calculate the width and height of other styles from those of the original" do
                  @thing.attachment.aspect_ratio(:double).should be_close(10, 1e-5)
                end

                it "should take into account the filledness of the style" do
                  @thing.attachment.aspect_ratio(:filled).should be_close(1, 1e-5)
                end
              end
            end

            describe "when the file is removed and the record reloaded (file is missing)" do
              before do
                File.unlink(@thing.attachment.path(:original))
                @thing = Thing.find(@thing.id)
              end

              describe "#width" do
                it "should return the stored width for the original" do
                  @thing.attachment.width(:original).should == 40
                end
              end

              describe "#height" do
                it "should return the stored height for the original" do
                  @thing.attachment.height(:original).should == 30
                end
              end

              describe "#dimensions" do
                it "should return the stored width and height for the original" do
                  @thing.attachment.dimensions(:original).should == [40, 30]
                end
              end

              describe "#aspect_ratio" do
                it "should return the stored aspect ratio for the original" do
                  @thing.attachment.aspect_ratio(:original).should be_close(4.0/3, 1e-5)
                end
              end
            end
          end
        end

        describe "when the attachment is assigned nil" do
          before do
            @thing.attachment = nil
          end

          it "should clear the stored attributes" do
            @thing.attachment_width.should be_nil
            @thing.attachment_height.should be_nil
          end
        end
      end
    end

    describe "when the width and height are not stored" do
      use_model_class(:Thing, :attachment_file_name => :string)

      it_should_behave_like_whether_or_not_the_width_and_height_are_stored(params)

      before do
        Thing.has_attachment :attachment do
          type params[:type]
          style :double, :size => '80x60'
          style :filled, :size => '60x60', :filled => true
          style :unfilled, :size => '120x120'
          default_style :double
        end
      end

      describe "when a record is created with an attachment" do
        before do
          @thing = Thing.create!(:attachment => uploaded_file(params[:file_40x30]))
        end

        describe "when the record is reinstantiated" do
          it "should log the system calls to find the dimensions"
        end

        describe "when the record is reinstantiated but the file is missing" do
          w, h = *params[:missing_dimensions]

          before do
            File.unlink(@thing.attachment.path(:original))
            @thing = Thing.find(@thing.id)
          end

          describe "#width" do
            it "should return #{w} for the original" do
              @thing.attachment.width(:original).should == w
            end
          end

          describe "#height" do
            it "should return #{h} for the original" do
              @thing.attachment.height(:original).should == h
            end
          end

          describe "#dimensions" do
            it "should return [#{w}, #{h}] for the original" do
              @thing.attachment.dimensions(:original).should == [w, h]
            end
          end

          describe "#aspect_ratio" do
            it "should return #{w}/#{h} for the original" do
              @thing.attachment.aspect_ratio(:original).should be_close(w.to_f/h, 1e-5)
            end
          end
        end
      end
    end
  end

  Spec::Runner.configure{|c| c.extend self}
end
