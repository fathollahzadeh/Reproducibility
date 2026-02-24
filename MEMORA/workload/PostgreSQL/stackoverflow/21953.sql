WITH RankedVotes AS (
    SELECT 
        P.Id AS PostId,
        U.DisplayName AS UserName,
        V.VoteTypeId,
        RANK() OVER (PARTITION BY P.Id ORDER BY V.CreationDate DESC) AS VoteRank
    FROM 
        Votes V
    JOIN 
        Posts P ON V.PostId = P.Id
    JOIN 
        Users U ON V.UserId = U.Id
),
CombinedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PHT.Name AS ChangeType,
        COUNT(*) AS ChangeCount,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate > cast('2024-10-01' as date) - INTERVAL '90 days'
    GROUP BY 
        PH.PostId, PH.UserId, PHT.Name
),
FinalData AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(RV.UserName, 'No Votes') AS LastVoter,
        COALESCE(RV.VoteTypeId, 0) AS LastVoteType,
        CPH.UserId AS LastChangeUserId,
        CPH.ChangeType,
        CPH.ChangeCount,
        CPH.LastChangeDate,
        T.TagName
    FROM 
        Posts P
    LEFT JOIN 
        RankedVotes RV ON P.Id = RV.PostId AND RV.VoteRank = 1
    LEFT JOIN 
        CombinedPostHistory CPH ON P.Id = CPH.PostId
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.CreationDate <= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND (P.Score > 5 OR P.ViewCount > 1000)
        AND (CPH.ChangeCount IS NULL OR CPH.ChangeCount < 10)
    ORDER BY 
        P.CreationDate DESC 
    LIMIT 100
)
SELECT 
    FD.*,
    (SELECT STRING_AGG(DISTINCT A.UserDisplayName, ', ') 
     FROM Comments A 
     WHERE A.PostId = FD.PostId) AS Commenters,
    (SELECT COUNT(*) 
     FROM PostHistory PH 
     WHERE PH.PostId = FD.PostId 
           AND PH.PostHistoryTypeId IN (10, 11)) AS ClosureCount,
    (CASE 
        WHEN FD.LastVoteType = 2 THEN 'Last Vote: Upvote'
        WHEN FD.LastVoteType = 3 THEN 'Last Vote: Downvote'
        ELSE 'No Recent Votes'
     END) AS VoteStatus
FROM 
    FinalData FD
WHERE 
    EXISTS (SELECT 1 FROM Badges B WHERE B.UserId = FD.LastChangeUserId AND B.Class = 1)
    AND FD.LastChangeDate >= cast('2024-10-01' as date) - INTERVAL '60 days';