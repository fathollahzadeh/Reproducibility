
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, u.DisplayName
),

TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(ps.UpVoteCount) AS TotalUpVotes,
        SUM(ps.DownVoteCount) AS TotalDownVotes,
        SUM(ps.CloseVotes) AS TotalCloseVotes
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    GROUP BY 
        t.TagName
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(ps.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(ps.DownVoteCount, 0)) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 10
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ts.TagName,
    ts.PostCount AS RelatedPostsCount,
    tu.DisplayName AS TopUser,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    PostStatistics ps
JOIN 
    TagStatistics ts ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
JOIN 
    TopUsers tu ON ps.OwnerDisplayName = tu.DisplayName
ORDER BY 
    ps.LastActivityDate DESC;
