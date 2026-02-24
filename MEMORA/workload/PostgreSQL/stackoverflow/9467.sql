
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostUserDetails AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        p.Id AS PostId
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount,
    pvs.Upvotes,
    pvs.Downvotes,
    pud.DisplayName,
    pud.Reputation
FROM 
    RankedPosts rp
JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
JOIN 
    PostUserDetails pud ON rp.PostId = pud.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.PostId, rp.ViewCount DESC;
