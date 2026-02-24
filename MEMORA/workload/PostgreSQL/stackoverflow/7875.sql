
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.LastAccessDate,
        ROW_NUMBER() OVER (ORDER BY u.CreationDate DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
TopPostsWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        pc.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tpp.Title,
    tpp.CreationDate,
    tpp.Score,
    tpp.ViewCount,
    tpp.AnswerCount,
    u.DisplayName AS TopUser,
    u.Reputation,
    u.Views
FROM 
    TopPostsWithComments tpp
JOIN 
    Users u ON tpp.AnswerCount > 0 AND u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tpp.PostId LIMIT 1)
JOIN 
    RecentUsers ru ON u.Id = ru.UserId
ORDER BY 
    tpp.Score DESC, tpp.ViewCount DESC
FETCH FIRST 20 ROWS ONLY;
