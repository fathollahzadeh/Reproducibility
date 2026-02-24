WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COALESCE(U.UpVotes - U.DownVotes, 0) AS NetVotes
    FROM 
        Users U
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(C.COMMENTS) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS COMMENTS FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, P.AcceptedAnswerId, P.OwnerUserId, P.CreationDate, P.Score
),
RankedPosts AS (
    SELECT 
        PD.*,
        US.DisplayName,
        US.Reputation,
        US.NetVotes,
        RANK() OVER (ORDER BY PD.Score DESC, PD.TotalBounty DESC) AS PostRank
    FROM 
        PostDetails PD
    JOIN 
        UserScores US ON PD.OwnerUserId = US.UserId
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        DisplayName,
        Score,
        Reputation,
        TotalBounty,
        UserPostRank
    FROM 
        RankedPosts
    WHERE 
        Reputation > 1000 
        AND PostRank <= 10 
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.DisplayName AS Owner,
    FP.Score,
    FP.Reputation,
    CASE
        WHEN FP.TotalBounty > 0 THEN 'This post has a bounty!'
        ELSE 'No bounty on this post'
    END AS BountyStatus,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = FP.PostId) AS NumberOfComments,
    (SELECT STRING_AGG(CONCAT('[', PHT.Name, ']'), ', ') 
     FROM PostHistory PH 
     JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id 
     WHERE PH.PostId = FP.PostId AND PH.UserId <> (SELECT OwnerUserId FROM Posts WHERE Id = FP.PostId)) AS EditReasons
FROM 
    FilteredPosts FP
ORDER BY 
    FP.Score DESC, 
    FP.Reputation DESC;