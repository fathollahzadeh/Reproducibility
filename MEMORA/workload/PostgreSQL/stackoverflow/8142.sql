
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        u.Reputation,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        au.DisplayName AS TopUser,
        au.UpVotesReceived,
        au.DownVotesReceived,
        au.Reputation
    FROM 
        RankedPosts p
    JOIN 
        ActiveUsers au ON p.PostId IN (SELECT postId FROM Posts WHERE OwnerUserId = au.UserId)
    WHERE 
        p.PostRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.TopUser,
    tp.UpVotesReceived,
    tp.DownVotesReceived,
    tp.Reputation
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC;
