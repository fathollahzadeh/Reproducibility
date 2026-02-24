WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserId AS EditorId,
        U.DisplayName AS EditorName,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditorHistoryRank
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  
), 
FilteredPostInfo AS (
    SELECT 
        PI.PostId,
        PI.Title,
        PI.Score,
        PI.PostHistoryTypeId,
        PI.CreationDate,
        PI.EditorId,
        PI.EditorName,
        PI.EditorHistoryRank,
        COALESCE(B.TotalVotes, 0) AS TotalUserVotes
    FROM 
        PostInfo PI
    LEFT JOIN 
        UserVoteSummary B ON PI.EditorId = B.UserId
    WHERE 
        PI.Score > 10  
)

SELECT 
    FPI.PostId,
    FPI.Title,
    MAX(FPI.CreationDate) AS LastEditDate,
    FPI.EditorName,
    FPI.TotalUserVotes,
    CASE 
        WHEN FPI.TotalUserVotes BETWEEN 1 AND 5 THEN 'Novice Editor'
        WHEN FPI.TotalUserVotes BETWEEN 6 AND 15 THEN 'Intermediate Editor'
        ELSE 'Veteran Editor'
    END AS EditorExperienceLevel,
    STRING_AGG(DISTINCT T.TagName, ', ') AS RelatedTags
FROM 
    FilteredPostInfo FPI
LEFT JOIN 
    Posts P ON FPI.PostId = P.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, ',')) AS TagName
    ) AS T ON TRUE
GROUP BY 
    FPI.PostId, FPI.Title, FPI.EditorName, FPI.TotalUserVotes
HAVING 
    COUNT(FPI.EditorHistoryRank) > 2  
ORDER BY 
    LastEditDate DESC
LIMIT 100;