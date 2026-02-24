
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END), 0) AS AcceptedAnswers,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.AcceptedAnswers
    FROM 
        PostStatistics ps
    WHERE 
        ps.RN <= 5
)
SELECT 
    u.DisplayName,
    SUM(tp.UpVotes) AS TotalUpVotes,
    AVG(tp.CommentCount) AS AverageComments,
    SUM(tp.AcceptedAnswers) AS TotalAcceptedAnswers
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.PostId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalUpVotes DESC
LIMIT 10;
