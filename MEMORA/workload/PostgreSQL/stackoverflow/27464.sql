
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            WHEN v.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) AS VoteScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            WHEN v.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) DESC, COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Tags, p.OwnerUserId
)

SELECT 
    rp.PostID,
    rp.Title,
    rp.Tags,
    rp.VoteScore,
    rp.CommentCount,
    rp.BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.PostID = p.Id
LEFT JOIN 
    Tags t ON t.TagName IN (SELECT UNNEST(string_to_array(rp.Tags, ',')))
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostID, rp.Title, rp.Tags, rp.VoteScore, rp.CommentCount, rp.BadgeCount
ORDER BY 
    rp.VoteScore DESC, rp.CommentCount DESC;
