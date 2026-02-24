
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
        P.Score > 0
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),
UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS AnsweredQuestions
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        COALESCE(PV.TagName, 'No Tag') AS Tag,
        US.UpVotes,
        US.DownVotes
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PopularTags PV ON RP.PostId IN (SELECT P.Id FROM Posts P WHERE P.Tags LIKE '%' || PV.TagName || '%')
    LEFT JOIN 
        UserVoteSummary US ON RP.OwnerDisplayName = US.DisplayName
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Tag,
    PD.UpVotes,
    PD.DownVotes,
    CASE 
        WHEN PD.UpVotes IS NULL THEN 'No Votes Yet'
        WHEN PD.DownVotes > PD.UpVotes THEN 'Downvoted Majority'
        ELSE 'Upvoted Majority'
    END AS VoteSummary
FROM 
    PostDetails PD
WHERE 
    PD.UpVotes IS NOT NULL
ORDER BY 
    PD.CreationDate DESC
LIMIT 50;
