
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(p.LastActivityDate) AS LastActivity,
        p.Score,
        p.CreationDate
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Score, p.CreationDate
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.AnswerCount) AS TotalAnswers,
        SUM(ps.UpVoteCount) AS TotalUpVotes,
        SUM(ps.DownVoteCount) AS TotalDownVotes
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN PostStats ps ON u.Id = ps.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBadges,
        TotalComments,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY TotalUpVotes DESC, TotalAnswers DESC, TotalComments DESC) AS UserRank
    FROM 
        TopUsers
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    TotalComments,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    UserRank
FROM 
    RankedUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
