
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(CASE 
                WHEN p.PostTypeId = 1 THEN 1 
                ELSE 0 
            END) AS TotalQuestions,
        SUM(CASE 
                WHEN p.PostTypeId = 2 THEN 1 
                ELSE 0 
            END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
             PostId,
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
             Votes
         GROUP BY 
             PostId) v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(CASE 
                WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 
                END) AS CloseChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
), RankedUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY (ups.TotalUpVotes - ups.TotalDownVotes) DESC) AS Ranking
    FROM 
        UserPostStats ups
)
SELECT 
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalUpVotes,
    ru.TotalDownVotes,
    CASE 
        WHEN rph.CloseChangeCount > 0 THEN 'Closed/Modified'
        ELSE 'Active'
    END AS PostStatus,
    rph.LastChangeDate
FROM 
    RankedUsers ru
LEFT JOIN 
    RecentPostHistory rph ON ru.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rph.PostId LIMIT 1)
WHERE 
    ru.Ranking <= 10
ORDER BY 
    (ru.TotalUpVotes - ru.TotalDownVotes) DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
