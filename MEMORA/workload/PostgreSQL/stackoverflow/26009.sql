
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank <= 5  
),
PopularTags AS (
    SELECT 
        t.TagName,  
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            UNNEST(string_to_array(Tags, '><')) AS TagName  
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1
    ) AS t
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10  
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.BadgeCount,
    tq.BadgeNames,
    pt.TagName,
    pt.TagCount
FROM 
    TopQuestions tq
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT UNNEST(string_to_array(tq.Tags, '><')))  
ORDER BY 
    tq.Score DESC, tq.CreationDate DESC;
