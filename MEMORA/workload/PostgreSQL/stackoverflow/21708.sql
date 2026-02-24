WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.AcceptedAnswerId IS NOT NULL
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserPostSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount,
        COALESCE(SUM(CASE WHEN ph.CloseCount > 0 THEN 1 ELSE 0 END), 0) AS ClosedPostsCount,
        COALESCE(SUM(CASE WHEN ph.DeleteCount > 0 THEN 1 ELSE 0 END), 0) AS DeletedPostsCount,
        COALESCE(MAX(ph.LastEditDate), '1970-01-01') AS LastEditedPost
    FROM 
        Users U
    LEFT JOIN 
        Posts p ON U.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistoryDetails ph ON p.Id = ph.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostsCount,
    U.QuestionsCount,
    U.AnswersCount,
    COALESCE(UP.VoteCount, 0) AS TotalVotes,
    COALESCE(UP.UpVotes, 0) AS UpVotes,
    COALESCE(UP.DownVotes, 0) AS DownVotes,
    U.ClosedPostsCount,
    U.DeletedPostsCount,
    U.LastEditedPost,
    A.PostId AS AcceptedPostId,
    A.OwnerUserId AS AnswerOwnerId
FROM 
    UserPostSummary U
LEFT JOIN 
    UserVotes UP ON U.UserId = UP.UserId
LEFT JOIN 
    AcceptedAnswers A ON U.UserId = A.OwnerUserId
WHERE 
    U.PostsCount > 0
ORDER BY 
    U.PostsCount DESC,
    UP.UpVotes DESC NULLS LAST
LIMIT 100;