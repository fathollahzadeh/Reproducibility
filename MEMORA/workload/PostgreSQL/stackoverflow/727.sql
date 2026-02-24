
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY TotalScore DESC) AS RankScore,
        RANK() OVER (ORDER BY UpVotes DESC) AS RankUpVotes
    FROM 
        UserActivity
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    COALESCE(tu.PostCount, 0) AS PostCount,
    COALESCE(tu.TotalScore, 0) AS TotalScore,
    COALESCE(tu.UpVotes, 0) AS UpVotes,
    COALESCE(tu.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN tu.RankScore <= 10 THEN 'Top 10 by Score'
        ELSE 'Not in Top 10'
    END AS ScoreCategory,
    CASE 
        WHEN tu.RankUpVotes <= 10 THEN 'Top 10 by UpVotes'
        ELSE 'Not in Top 10'
    END AS VoteCategory
FROM 
    TopUsers tu
WHERE 
    tu.TotalScore IS NOT NULL
    OR tu.UpVotes IS NOT NULL
ORDER BY 
    tu.TotalScore DESC, 
    tu.UpVotes DESC;
