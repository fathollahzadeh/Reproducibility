
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    GROUP BY 
        UNNEST(string_to_array(Tags, '>'))
    HAVING 
        COUNT(*) > 5
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
    HAVING 
        COUNT(c.Id) > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ue.UserId,
    ue.Reputation,
    ue.TotalComments,
    ue.TotalBounties,
    pt.TagName,
    pt.TagCount,
    pc.CommentCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'No score' 
        ELSE CASE 
            WHEN rp.Score < 0 THEN 'Negative Score' 
            ELSE 'Positive Score' 
        END 
    END AS ScoreCategory,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'Unknown Views'
        WHEN rp.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Low Views'
    END AS ViewCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserEngagement ue ON ue.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.Tags, '>'))
LEFT JOIN 
    PostComments pc ON pc.PostId = rp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, ue.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
