WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id
),
PopularPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.CommentCount,
        PS.RelatedPostCount,
        PS.CloseCount,
        U.DisplayName AS OwnerName,
        U.Reputation AS OwnerReputation,
        U.CreationDate AS UserCreationDate,
        CASE 
            WHEN U.Reputation IS NULL THEN 'Anonymous'
            WHEN U.Reputation < 100 THEN 'Newbie'
            WHEN U.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS UserStatus,
        (SELECT COUNT(*) FROM Votes WHERE PostId = PS.PostId AND VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = PS.PostId AND VoteTypeId = 3) AS DownvoteCount
    FROM 
        PostStats PS
    LEFT JOIN 
        Users U ON PS.PostId = U.Id
    WHERE 
        PS.Score >= 10 AND
        PS.RelatedPostCount > 0
)
SELECT 
    PP.Title,
    PP.ViewCount,
    PP.CommentCount,
    PP.RelatedPostCount,
    PP.CloseCount,
    PP.OwnerName,
    PP.OwnerReputation,
    PP.UserStatus,
    COALESCE(VS.Upvotes, 0) AS UserUpvotes,
    COALESCE(VS.Downvotes, 0) AS UserDownvotes,
    (PP.UpvoteCount - PP.DownvoteCount) AS NetVotes,
    CASE 
        WHEN PP.CloseCount = 0 THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus
FROM 
    PopularPosts PP
LEFT JOIN 
    UserVoteStats VS ON PP.OwnerName = VS.DisplayName
ORDER BY 
    PP.ViewCount DESC, 
    PP.CommentCount DESC;
