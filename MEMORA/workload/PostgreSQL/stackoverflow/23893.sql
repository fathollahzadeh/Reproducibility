
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.CommentCount,
        P.AnswerCount,
        PH.CreationDate AS LastHistoryDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY PH.CreationDate DESC) AS LastHistoryRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
),
UserPostSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(P.LastActivityDate) AS LastActivity,
        MAX(P.CreationDate) AS FirstPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
CombinedSummary AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.QuestionCount,
        UPS.AnswerCount,
        CONCAT_WS(' | ', 
            COALESCE(CAST(UPS.FirstPostDate AS TEXT), 'No Posts'), 
            COALESCE(CAST(UPS.LastActivity AS TEXT), 'Inactive')) AS ActivitySummary,
        COALESCE(UVS.TotalVotes, 0) AS TotalVotes,
        COALESCE(UVS.UpVotes, 0) AS UpVotes,
        COALESCE(UVS.DownVotes, 0) AS DownVotes
    FROM 
        UserPostSummary UPS
    LEFT JOIN 
        UserVoteSummary UVS ON UPS.UserId = UVS.UserId
)
SELECT 
    CS.DisplayName,
    CS.TotalPosts,
    CS.QuestionCount,
    CS.AnswerCount,
    CS.TotalVotes,
    CS.UpVotes,
    CS.DownVotes,
    CS.ActivitySummary
FROM 
    CombinedSummary CS
WHERE 
    CS.TotalPosts > 0 
    AND (CS.UpVotes - CS.DownVotes) > 10 
    AND NOT EXISTS (
        SELECT 1 
        FROM Users U
        WHERE U.Id = CS.UserId 
        AND (U.Reputation < 50 OR U.CreationDate > '2023-01-01')
    )
ORDER BY 
    CS.TotalVotes DESC, 
    CS.DisplayName;
