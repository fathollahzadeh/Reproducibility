WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
ClosedPostDetails AS (
    SELECT 
        P.Id AS PostId,
        COUNT(PH.Id) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        P.Id
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(CLOSED.CloseCount, 0) AS ClosedPosts,
        COALESCE(PS.VoteCount, 0) AS TotalVotes,
        COALESCE(PS.UpVotes, 0) AS TotalUpVotes,
        COALESCE(PS.DownVotes, 0) AS TotalDownVotes,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostVoteStats PS ON P.Id = PS.PostId
    LEFT JOIN 
        ClosedPostDetails CLOSED ON P.Id = CLOSED.PostId
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    GROUP BY 
        U.Id, CLOSED.CloseCount, PS.VoteCount, PS.UpVotes, PS.DownVotes, UBC.BadgeCount
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    USP.TotalPosts,
    USP.ClosedPosts,
    USP.TotalVotes,
    USP.TotalUpVotes,
    USP.TotalDownVotes,
    USP.BadgeCount
FROM 
    UserPostStats USP
JOIN 
    Users U ON USP.UserId = U.Id
WHERE 
    USP.TotalPosts > 10
ORDER BY 
    U.Reputation DESC, USP.TotalPosts DESC;
