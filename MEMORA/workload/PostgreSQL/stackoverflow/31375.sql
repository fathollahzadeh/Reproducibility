
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN VT.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VT.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COUNT(P.Id) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes VT ON P.Id = VT.PostId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpVoteCount,
        DownVoteCount
    FROM UserActivity
    WHERE UserRank <= 10 
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(MAX(PH.PostHistoryTypeId), 0) AS LastActionType,
        MAX(PH.CreationDate) AS LastActionDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.CommentCount,
        PS.LastActionType,
        PS.LastActionDate,
        T.TagName
    FROM PostStats PS
    LEFT JOIN Tags T ON PS.PostId = T.ExcerptPostId
    WHERE PS.Score >= 10 AND (PS.CommentCount > 0 OR PS.LastActionType IN (10, 11))
),
RankedPosts AS (
    SELECT 
        FP.*,
        RANK() OVER (ORDER BY FP.Score DESC, FP.CommentCount DESC) AS PostRank
    FROM FilteredPosts FP
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    RP.Title,
    RP.Score,
    RP.CommentCount,
    RP.LastActionDate
FROM TopUsers TU
JOIN RankedPosts RP ON TU.UserId = RP.PostId
WHERE RP.PostRank <= 5
ORDER BY TU.Reputation DESC, RP.Score DESC;
