
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS TotalVotes,
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
        p.ParentId,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 2 THEN 1 ELSE 0 END) AS EditBodyCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.ParentId, p.ViewCount
),

AnsweredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId,
        p.Title,
        COALESCE(a.OwnerDisplayName, 'N/A') AS AcceptedAnswerOwner
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    aps.AcceptedAnswerOwner,
    uvs.DisplayName AS UserVoteDisplayName,
    uvs.TotalVotes, 
    uvs.UpVotes, 
    uvs.DownVotes,
    ps.CloseReopenCount,
    ps.EditBodyCount
FROM 
    PostStatistics ps
LEFT JOIN 
    AnsweredPosts aps ON ps.PostId = aps.PostId
LEFT JOIN 
    UserVoteSummary uvs ON ps.PostId = (
        SELECT 
            v.PostId 
        FROM 
            Votes v 
        WHERE 
            v.UserId = uvs.UserId 
        ORDER BY 
            v.CreationDate DESC 
        LIMIT 1
    )
WHERE 
    ps.ViewCount > 100
ORDER BY 
    ps.CommentCount DESC, ps.ViewCount DESC
LIMIT 20;
