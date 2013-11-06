App.ApplianceType = DS.Model.extend
  name:              DS.attr('string')
  description:       DS.attr('string')
  shared:            DS.attr('boolean')
  scalable:          DS.attr('boolean')
  visible_for:       DS.attr('string')
  preference_cpu:    DS.attr('string')
  preference_memory: DS.attr('string')
  preference_disk:   DS.attr('string')
  author:            DS.belongsTo('user')

  published: (->
    @get('visible_for') == 'all'
  ).property 'visible_for'

  author_name: (->
    if @get('author') == null
      'anonymous'
    else
      @get('author.login')
  ).property 'author.login'
