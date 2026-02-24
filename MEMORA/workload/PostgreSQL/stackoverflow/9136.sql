
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopRankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalWikis,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        MAX(v.CreationDate) AS LastVoteDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
PopularPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.TotalComments,
        pa.LastVoteDate,
        pa.UpVotes,
        pa.DownVotes,
        RANK() OVER (ORDER BY (pa.UpVotes - pa.DownVotes) DESC, pa.TotalComments DESC) AS PostRank
    FROM 
        PostActivity pa
)

SELECT 
    tru.DisplayName,
    tru.TotalPosts,
    tru.TotalQuestions,
    tru.TotalAnswers,
    tru.TotalWikis,
    tru.TotalScore,
    pp.Title AS PopularPostTitle,
    pp.TotalComments,
    pp.LastVoteDate,
    pp.UpVotes,
    pp.DownVotes
FROM 
    TopRankedUsers tru
JOIN 
    PopularPosts pp ON tru.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
WHERE 
    tru.Rank <= 10 AND pp.PostRank <= 10
ORDER BY 
    tru.TotalScore DESC, pp.UpVotes DESC;
