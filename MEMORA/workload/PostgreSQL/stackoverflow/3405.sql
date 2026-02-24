
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(NULLIF(u.Reputation, 0), 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND (p.ViewCount > 100 OR u.Reputation > 50)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.Reputation, p.OwnerUserId, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        PostRank,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        UserReputation
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
FinalPosts AS (
    SELECT 
        tp.*,
        pt.Name AS PostTypeName
    FROM 
        TopPosts tp
    INNER JOIN 
        PostTypes pt ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.UserReputation,
    fp.PostTypeName
FROM 
    FinalPosts fp
ORDER BY 
    fp.ViewCount DESC, 
    fp.UpVoteCount DESC
FETCH FIRST 10 ROWS ONLY;
