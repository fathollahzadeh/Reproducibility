WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
),
TopPosts AS (
    SELECT 
        PostID,
        Title,
        CreationDate,
        Score,
        ViewCount,
        UpVoteCount,
        DownVoteCount,
        PostRank,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
PostStatistics AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostID) AS TotalPosts,
        SUM(UpVoteCount) AS TotalUpVotes,
        SUM(DownVoteCount) AS TotalDownVotes,
        AVG(Score) AS AverageScore
    FROM 
        TopPosts
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalPosts,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.AverageScore,
    CASE 
        WHEN ps.TotalPosts > 10 THEN 'Expert'
        WHEN ps.TotalPosts BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Novice'
    END AS ExpertiseLevel
FROM 
    PostStatistics ps
ORDER BY 
    ps.TotalUpVotes DESC, 
    ps.AverageScore DESC;