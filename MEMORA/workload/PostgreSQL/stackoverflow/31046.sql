WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersProvided
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 

TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        QuestionsAsked,
        AnswersProvided,
        RANK() OVER (ORDER BY (UPVotes - DownVotes) DESC) AS Rank
    FROM 
        UserActivity
), 

RecentPostHistory AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        u.DisplayName AS EditorName,
        pt.Name AS PostType
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.UpVotes,
    tu.DownVotes,
    tu.QuestionsAsked,
    tu.AnswersProvided,
    rh.PostId,
    rh.PostHistoryTypeId,
    rh.CreationDate,
    rh.EditorName,
    rh.PostType
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPostHistory rh ON tu.UserId IN (
        SELECT DISTINCT p.OwnerUserId 
        FROM Posts p 
        WHERE p.Id = rh.PostId
    )
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, rh.CreationDate DESC;