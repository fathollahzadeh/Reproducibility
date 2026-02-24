
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN h.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN h.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeleteCount,
        SUM(CASE WHEN h.PostHistoryTypeId = 1 OR h.PostHistoryTypeId = 4 THEN 1 ELSE 0 END) AS TitleEditCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        AcceptedAnswers,
        UpVotes,
        DownVotes,
        CloseCount,
        DeleteCount,
        TitleEditCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    AnswerCount,
    AcceptedAnswers,
    UpVotes,
    DownVotes,
    CloseCount,
    DeleteCount,
    TitleEditCount,
    UserRank
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
