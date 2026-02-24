WITH RECURSIVE PostTree AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        Score,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        pt.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostTree pt ON p.ParentId = pt.Id  
),
UserVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.UserId
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COALESCE(tree.Level, 0) AS PostLevel,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
            ELSE 'No Accepted Answer'
        END AS AnswerStatus
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserVotes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTree tree ON p.Id = tree.Id
)
SELECT 
    ps.Id,
    ps.Title,
    ps.OwnerDisplayName,
    ps.PostLevel,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.AnswerStatus,
    CASE
        WHEN ps.TotalUpVotes - ps.TotalDownVotes > 0 THEN 'Positive'
        WHEN ps.TotalUpVotes - ps.TotalDownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.Id AND v.VoteTypeId = 2) AS UpVoteCount
FROM 
    PostStats ps
WHERE 
    (ps.TotalUpVotes > 5 OR ps.TotalDownVotes > 3) AND 
    ps.AnswerStatus = 'Accepted Answer'
ORDER BY 
    ps.PostLevel DESC, 
    ps.TotalUpVotes DESC
LIMIT 100;