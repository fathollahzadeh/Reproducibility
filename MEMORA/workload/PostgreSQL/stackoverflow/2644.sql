
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
        LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostsWithBadges AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(B.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS BadgeRank
    FROM 
        Posts P
        LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
        JOIN CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    P.Title AS PostTitle,
    P.BadgeCount,
    C.CloseReason,
    COALESCE(C.CreationDate, P.CreationDate) AS CloseOrCreationDate
FROM 
    UserVoteStats U
    LEFT JOIN PostsWithBadges P ON U.UserId = P.PostId
    LEFT JOIN ClosedPosts C ON P.PostId = C.PostId
WHERE 
    (U.UpVotes > U.DownVotes OR U.DownVotes IS NULL)
    OR (P.BadgeCount > 0 AND P.BadgeRank = 1)
ORDER BY 
    COALESCE(C.CreationDate, P.CreationDate) DESC;
