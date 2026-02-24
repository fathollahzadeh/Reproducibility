
WITH TagFrequency AS (
    SELECT
        UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM
        Posts
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        SUM(CASE WHEN v.VoteTypeId IN (6, 7) THEN 1 ELSE 0 END) AS VotesForCloseReopen
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM
        TagFrequency
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionsAsked,
        UpVotesReceived,
        DownVotesReceived,
        VotesForCloseReopen,
        ROW_NUMBER() OVER (ORDER BY QuestionsAsked DESC) AS UserRank
    FROM
        UserEngagement
)
SELECT
    tu.DisplayName AS TopUser,
    tu.QuestionsAsked,
    tu.UpVotesReceived,
    tu.DownVotesReceived,
    tt.Tag AS PopularTag,
    tt.Frequency AS TagFrequency
FROM
    TopUsers tu
JOIN
    TopTags tt ON tu.UserRank <= 10 AND tt.Rank <= 10
ORDER BY
    tu.QuestionsAsked DESC, tt.Frequency DESC;
