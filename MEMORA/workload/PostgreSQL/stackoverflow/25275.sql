WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON true
    GROUP BY 
        p.Id
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.UserId AS EditsByUserId,
        ph.CreationDate AS EditDate,
        STRING_AGG(pt.Name, ', ') AS PostHistoryTypeNames,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    pt.UniqueTagCount,
    pt.TagList,
    u.DisplayName AS OwnerName,
    ur.Reputation AS OwnerReputation,
    ur.PostCount,
    ur.QuestionCount,
    ur.AnswerCount,
    ub.BadgeCount,
    ub.BadgeNames,
    ph.EditsByUserId,
    ph.EditDate,
    ph.PostHistoryTypeNames,
    ph.EditCount
FROM 
    Posts p
JOIN 
    PostTagCounts pt ON p.Id = pt.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    p.CreationDate DESC
LIMIT 100;