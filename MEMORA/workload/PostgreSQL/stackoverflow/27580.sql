
WITH StringBenchmark AS (
    SELECT 
        PH.Id AS PostHistoryId,
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS UserDisplayName,
        PH.Comment,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        PH.Text AS NewValue,
        PH.UserId,
        PH.UserDisplayName AS EditorDisplayName,
        PT.Name AS PostType,
        (SELECT STRING_AGG(T.TagName, '; ')
         FROM Tags T 
         WHERE P.Tags LIKE CONCAT('%', T.TagName, '%')) AS RelatedTags,
        LENGTH(P.Body) AS BodyLength,
        LENGTH(P.Title) AS TitleLength,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS RevisionRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        Users U ON PH.UserId = U.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        PH.PostHistoryTypeId IN (1, 4, 5)  
)
SELECT 
    STRING_AGG(CONCAT('Post ID: ', PostId, 
                      '; Post Title: ', Title,
                      '; Length of Title: ', TitleLength,
                      '; Length of Body: ', BodyLength,
                      '; Last Editor: ', EditorDisplayName,
                      '; Date Edited: ', CreationDate,
                      '; Tags: ', RelatedTags), 
                ' | ') AS PostSummary,
    UserDisplayName
FROM 
    StringBenchmark
WHERE 
    RevisionRank = 1  
GROUP BY 
    UserDisplayName
ORDER BY 
    UserDisplayName;
