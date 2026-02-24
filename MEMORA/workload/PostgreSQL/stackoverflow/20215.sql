WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.ANSWERCOUNT,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.Reputation AS UserReputation,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 100
),
TopRankedPosts AS (
    SELECT 
        rp.*,
        (CASE 
            WHEN rp.UserReputation > 10000 THEN 'High' 
            WHEN rp.UserReputation BETWEEN 5000 AND 10000 THEN 'Medium' 
            ELSE 'Low' 
         END) AS ReputationLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)

SELECT 
    trp.PostID,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    trp.ReputationLevel,
    COALESCE(trp.Upvotes, 0) AS Upvotes,
    COALESCE(trp.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN trp.Upvotes - trp.Downvotes > 10 THEN 'Popular'
        WHEN trp.Upvotes - trp.Downvotes BETWEEN -10 AND 10 THEN 'Moderate'
        ELSE 'Unpopular'
    END AS PopularityTag
FROM 
    TopRankedPosts trp
ORDER BY 
    trp.ReputationLevel DESC, trp.Score DESC;