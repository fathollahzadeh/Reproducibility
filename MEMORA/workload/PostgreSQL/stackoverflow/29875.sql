WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Owner,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS RankPerTag,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        P.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT RP.PostId) AS NumberOfQuestions,
        AVG(RP.Score) AS AverageScore,
        SUM(RP.UpVotes) AS TotalUpVotes,
        SUM(RP.DownVotes) AS TotalDownVotes
    FROM 
        RankedPosts RP
    JOIN 
        UNNEST(string_to_array(RP.Tags, '><')) AS T(TagName) ON T.TagName IS NOT NULL
    GROUP BY 
        T.TagName
)
SELECT 
    TS.TagName,
    TS.NumberOfQuestions,
    TS.AverageScore,
    TS.TotalUpVotes,
    TS.TotalDownVotes,
    CASE 
        WHEN TS.AverageScore >= 10 THEN 'High'
        WHEN TS.AverageScore BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    TagStats TS
WHERE 
    TS.NumberOfQuestions > 5 
ORDER BY 
    TS.TotalUpVotes DESC, 
    TS.AverageScore DESC;