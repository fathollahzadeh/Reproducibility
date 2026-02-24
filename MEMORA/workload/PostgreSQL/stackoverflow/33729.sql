
WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), 
HighScorers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(P.Score), 0) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostVoteDetails AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT V.UserId) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    HSC.DisplayName,
    HSC.Reputation,
    HPC.PostCount,
    HSC.TotalScore,
    PD.PostId,
    PD.Upvotes,
    PD.Downvotes,
    (PD.Upvotes - PD.Downvotes) AS NetVotes,
    P.Title,
    P.CreationDate,
    ARRAY_AGG(DISTINCT T.TagName) AS Tags
FROM 
    HighScorers HSC
JOIN 
    UserPostCounts HPC ON HSC.UserId = HPC.UserId
LEFT JOIN 
    Posts P ON HSC.UserId = P.OwnerUserId
LEFT JOIN 
    PostVoteDetails PD ON P.Id = PD.PostId
LEFT JOIN 
    LATERAL (SELECT unnest(string_to_array(P.Tags, ',')) AS TagName) AS TagArray ON true
LEFT JOIN 
    Tags T ON T.TagName = TagArray.TagName
GROUP BY 
    HSC.DisplayName, 
    HSC.Reputation, 
    HPC.PostCount, 
    HSC.TotalScore,
    PD.PostId, 
    PD.Upvotes, 
    PD.Downvotes,
    P.Title, 
    P.CreationDate
ORDER BY 
    HSC.TotalScore DESC, 
    HSC.Reputation DESC
LIMIT 10;
