
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 months')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        Score,
        CommentCount,
        UpVoteCount
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVoteCount,
    CASE 
        WHEN ur.Reputation IS NULL THEN 'No Reputation Info'
        ELSE CAST(ur.Reputation AS VARCHAR)
    END AS UserReputation,
    COALESCE(t.TagName, 'Unlabeled') AS TagName
FROM 
    RecentPosts rp
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = rp.PostId
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
