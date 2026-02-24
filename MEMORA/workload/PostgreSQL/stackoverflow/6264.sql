WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.Views
),
TopUsersPosts AS (
    SELECT 
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalUpVotes,
        us.TotalDownVotes,
        RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 0
)
SELECT 
    uup.DisplayName,
    uup.TotalPosts,
    uup.TotalQuestions,
    uup.TotalAnswers,
    uup.TotalUpVotes,
    uup.TotalDownVotes,
    (uup.TotalUpVotes - uup.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN uup.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN uup.ReputationRank <= 50 THEN 'Active Contributor'
        ELSE 'Emerging Contributor'
    END AS ContributorLevel
FROM 
    TopUsersPosts uup
WHERE 
    uup.ReputationRank <= 100
ORDER BY 
    uup.ReputationRank;
