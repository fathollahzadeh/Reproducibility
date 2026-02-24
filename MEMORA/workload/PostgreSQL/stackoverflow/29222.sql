
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title AS PostTitle, 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
RankedPosts AS (
    SELECT 
        tp.PostId,
        tp.PostTitle,
        tp.Tag,
        ROW_NUMBER() OVER (PARTITION BY tp.Tag ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        TaggedPosts tp
    JOIN 
        Posts p ON p.Id = tp.PostId
    WHERE 
        p.ViewCount > 1000  
),
RecentEdits AS (
    SELECT 
        ph.PostId AS EditedPostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Tag,
    rp.PostTitle,
    re.LastEditDate,
    re.EditCount,
    ur.DisplayName AS UserName,
    ur.Reputation AS UserReputation,
    ur.BadgeCount AS UserBadgeCount
FROM 
    RankedPosts rp
JOIN 
    RecentEdits re ON rp.PostId = re.EditedPostId
JOIN 
    Posts p ON p.Id = rp.PostId
JOIN 
    Users u ON u.Id = p.OwnerUserId
JOIN 
    UserReputation ur ON ur.UserId = u.Id
WHERE 
    rp.TagRank <= 5  
ORDER BY 
    rp.Tag, re.LastEditDate DESC;
