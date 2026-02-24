WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS VoteRank
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
CommentStats AS (
    SELECT
        C.UserId,
        COUNT(*) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
ClosePostStats AS (
    SELECT 
        PH.UserId,
        COUNT(DISTINCT P.Id) AS ClosedPostCount,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
        JOIN Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.UserId
),
OverallStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.UpVotes,
        US.DownVotes,
        COALESCE(CS.CommentCount, 0) AS CommentCount,
        COALESCE(CS.LastCommentDate, '1900-01-01') AS LastCommentDate,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(CPS.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(CPS.LastCloseDate, '1900-01-01') AS LastCloseDate,
        US.VoteRank
    FROM 
        UserStats US
        LEFT JOIN CommentStats CS ON US.UserId = CS.UserId
        LEFT JOIN BadgeSummary BS ON US.UserId = BS.UserId
        LEFT JOIN ClosePostStats CPS ON US.UserId = CPS.UserId
)
SELECT 
    OS.DisplayName,
    OS.Reputation,
    OS.UpVotes,
    OS.DownVotes,
    OS.CommentCount,
    OS.GoldBadges + OS.SilverBadges + OS.BronzeBadges AS TotalBadges,
    OS.ClosedPostCount,
    CASE 
        WHEN OS.ClosedPostCount > 5 THEN 'Frequent Closer'
        WHEN OS.ClosedPostCount BETWEEN 1 AND 5 THEN 'Occasional Closer'
        ELSE 'Rarely Closes'
    END AS ClosingBehavior,
    ROW_NUMBER() OVER (ORDER BY OS.Reputation DESC) AS UserRank
FROM 
    OverallStats OS
WHERE 
    OS.Reputation > 1000 AND
    (OS.CommentCount > 0 OR OS.ClosedPostCount > 0)
ORDER BY 
    OS.Reputation DESC,
    OS.UserId
FETCH FIRST 100 ROWS ONLY;