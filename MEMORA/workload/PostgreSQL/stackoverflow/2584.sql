
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.ViewCount > 50
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Tags, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRanking
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.*, 
        ur.Reputation 
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.TagRank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.Reputation,
    CASE 
        WHEN tp.UpVoteCount IS NULL THEN 'No Votes'
        WHEN tp.Reputation > 1000 THEN 'High Reputation User'
        ELSE 'Normal User'
    END AS UserType
FROM 
    TopPosts tp
WHERE 
    (tp.Reputation > 500 OR tp.CommentCount > 10)
ORDER BY 
    tp.UpVoteCount DESC, tp.CommentCount DESC
FETCH FIRST 10 ROWS ONLY;
