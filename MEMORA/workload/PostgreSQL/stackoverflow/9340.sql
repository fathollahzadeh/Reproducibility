
WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(ph.UserId, 0) AS LastEditedBy,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(ph2.CreationDate) 
            FROM PostHistory ph2 
            WHERE ph2.PostId = p.Id
        )
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        uv.TotalVotes,
        uv.UpVotes,
        uv.DownVotes,
        ps.LastEditedBy
    FROM 
        PostStatistics ps
    JOIN 
        UserVoteStatistics uv ON ps.LastEditedBy = uv.UserId
    WHERE 
        ps.PostRank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.TotalVotes,
    tp.UpVotes,
    tp.DownVotes,
    u.DisplayName AS LastEditorDisplayName
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.LastEditedBy = u.Id
ORDER BY 
    tp.Score DESC;
