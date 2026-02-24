
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS Deletions
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), P.Id) AS DisplayPostId,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount,
        MAX(PH.CreationDate) AS LastUpdateDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON PL.PostId = P.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= DATE '2023-01-01'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        PS.PostId, 
        PS.Title,
        PS.ViewCount, 
        PS.CommentCount, 
        PS.RelatedPostsCount,
        PS.LastUpdateDate,
        ROW_NUMBER() OVER (ORDER BY PS.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY PS.CommentCount DESC, PS.ViewCount DESC) AS CommentRank
    FROM 
        PostStats PS
)

SELECT 
    UP.UserId,
    UP.DisplayName,
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CommentCount,
    RP.RelatedPostsCount,
    RP.LastUpdateDate,
    UP.UpVotes,
    UP.DownVotes,
    UP.Deletions,
    CASE 
        WHEN UP.UpVotes > UP.DownVotes THEN 'Positive'
        WHEN UP.UpVotes < UP.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN RP.CommentCount > 20 THEN 'Highly Discussed'
        WHEN RP.CommentCount BETWEEN 5 AND 20 THEN 'Moderately Discussed'
        ELSE 'Discussion Light'
    END AS DiscussionLevel
FROM 
    UserVoteCounts UP
INNER JOIN 
    RankedPosts RP ON RP.ViewRank <= 10 
WHERE 
    (UP.Deletions = 0 OR RP.CommentCount > 0)
ORDER BY 
    UP.UserId, RP.ViewCount DESC;
