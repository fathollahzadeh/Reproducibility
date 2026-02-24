
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        p.AnswerCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
        AND p.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        ViewCount,
        AnswerCount,
        Reputation
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes,
    COALESCE(ps.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN tp.Reputation > 1000 THEN 'High Reputation'
        WHEN tp.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    TopPosts tp
LEFT JOIN 
    PostStats ps ON tp.PostId = ps.PostId
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC
LIMIT 10;
