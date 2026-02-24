
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteNetScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS rn
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), RecentPostComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY MAX(c.CreationDate) DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title
), ComplexPostAnalysis AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT l.RelatedPostId) AS RelatedPostCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer' 
            ELSE 'No Accepted Answer' 
        END AS AnswerStatus,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRanking
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostLinks l ON p.Id = l.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId
)
SELECT 
    ups.DisplayName,
    ups.Reputation,
    ups.UpVotesCount,
    ups.DownVotesCount,
    ups.VoteNetScore,
    pp.Title AS PopularPostTitle,
    pp.TotalComments,
    pp.TotalUpVotes,
    pp.TotalDownVotes,
    pp.RelatedPostCount,
    pp.AnswerStatus
FROM 
    UserVoteStats ups
JOIN 
    ComplexPostAnalysis pp ON ups.UserId = pp.Id
WHERE 
    ups.rn = 1 AND pp.VoteRanking <= 5
ORDER BY 
    ups.VoteNetScore DESC, pp.TotalUpVotes DESC;
